import UIKit

final class ProfileViewController: UIViewController {
    @IBOutlet private var avatarImageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var loginNameLabel: UIView!
    @IBOutlet private var descriptionLabel: UILabel!
    
    
    @IBOutlet private var logoutButton: UIButton!
    
    @IBAction private func didTaplogoutButton() {
    }
}
